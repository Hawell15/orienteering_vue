<template>
    <h1 style="text-align:center; color:green">Grupe</h1>
    <input type="text" v-model="filters.search" placeholder="Cautare" class="form-control" />
    <hr>
    <div class="filter-item">
        <label for="club" class="label-filter">Competitia</label>
        <select id="competition" v-model="filters.competition" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="competition in filterData.competitions" :key="competition.id" :value="competition.id">{{ competition.competition_display}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label class="label-filter">Data</label>
        <div class="range-wrapper">
            <input type="date" v-model="filters['date[from]']" min="0" class="custom-input" placeholder="De la" />
            <span class="range-separator">—</span>
            <input type="date" v-model="filters['date[to]']" min="0" class="custom-input" placeholder="Până la" />
        </div>
    </div>
    <div class="filter-item">
        <label class="label-filter">Numar Rezultate</label>
        <div class="range-wrapper">
            <input type="number" v-model="filters['results_count[from]']" min="0" class="custom-input" placeholder="De la" />
            <span class="range-separator">—</span>
            <input type="number" v-model="filters['results_count[to]']" min="0" class="custom-input" placeholder="Până la" />
        </div>
    </div>
    <button class="btn btn-sm btn-danger" @click="resetFilters">Reseteaza Filtrele</button>
    <hr>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('group_name')">Grupa</th>
                <th @click="orderTable('competition_name')">Competiția</th>
                <th @click="orderTable('date')">Data</th>
                <th @click="orderTable('rang')">Rang</th>
                <th @click="orderTable('clasa')">Clasa</th>
                <th @click="orderTable('ecn_coeficient')">ECN Coeficient</th>
                <th @click="orderTable('results_count')">Rezultate</th>
                <th colspan="3">Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td><a :href="`groups/${element.id}`">{{element.id}}</a></td>
                <td><a :href="`groups/${element.id}`">{{element.group_name}}</a></td>
                <td><a :href="`competitions/${element.competition_id}`">{{element.competition_name}}</a></td>
                <td>{{element.date}}</td>
                <td>{{element.rang}}</td>
                <td>{{element.clasa_name}}</td>
                <td>{{element.ecn_coeficient}}</td>
                <td><a :href="`results?group_id=${element.id}`">{{element.results_count}}</a></td>
                <td><a class="btn btn-sm btn-warning" :href="`groups/${element.id}`"> Arată </a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'

const data = ref([])
const filterData = ref({})

const DEFAULT_FILTERS = {
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc",
    "results_count[from]": 0,
    "results_count[to]": 9999,
    "date[from]": "2000-01-01",
    "date[to]": "2100-01-01",
    "competition": "all"
}

const filters = reactive({ ...DEFAULT_FILTERS });

let debounceTimeout = null;

watch(
    filters,
    (newVal) => {
        clearTimeout(debounceTimeout);

        debounceTimeout = setTimeout(() => {
            getData();
        }, 400);
    }, { deep: true }
);

async function getData() {
    const cleanParams = {};

    const rangePairs = [
        { from: "results_count[from]", to: "results_count[to]" },
        { from: "date[from]", to: "date[to]" },
    ];

    const keysToSkip = new Set();

    if (filters.search === "") {
        keysToSkip.add("search")
    }

    rangePairs.forEach(pair => {
        const currentFrom = filters[pair.from];
        const currentTo = filters[pair.to];
        const defaultFrom = DEFAULT_FILTERS[pair.from];
        const defaultTo = DEFAULT_FILTERS[pair.to];

        if (currentFrom === defaultFrom && currentTo === defaultTo) {
            keysToSkip.add(pair.from);
            keysToSkip.add(pair.to);
        }
    });

    Object.keys(filters).forEach(key => {
        let value = filters[key];

        if (keysToSkip.has(key)) return;

        if (value === "all") return;

        if (key !== 'search' && (value === "" || value === null)) {
            value = DEFAULT_FILTERS[key];
        }

        cleanParams[key] = value;
    });

    try {
        const res = await axios.get('/groups.json', { params: cleanParams });
        data.value = res.data;

        const queryString = new URLSearchParams(cleanParams).toString();
        const urlPrefix = window.location.pathname;
        const newUrl = queryString ? `${urlPrefix}?${queryString}` : urlPrefix;

        window.history.replaceState({}, '', newUrl);
    } catch (error) {
        console.error("API Error:", error);
    }
}

onMounted(() => {
    getFiltersData()
    const urlParams = new URLSearchParams(window.location.search);

    urlParams.forEach((value, key) => {
        if (key in filters) {
            const isNumber = typeof DEFAULT_FILTERS[key] === 'number';
            filters[key] = isNumber ? Number(value) : value;
        }
    });
    getData();
})

async function getFiltersData() {
    const res = await axios.get('groups/filters.json')
    filterData.value = res.data
}

function orderTable(sortKey) {
    const isCurrentSort = filters["sorting[sort_by]"] === sortKey;
    const currentDir = filters["sorting[direction]"];

    filters["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters["sorting[sort_by]"] = sortKey;
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}
</script>
