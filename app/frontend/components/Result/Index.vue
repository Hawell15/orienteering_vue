<template>
    <h1 style="text-align:center; color:green">Rezultate</h1>
    <input type="text" v-model="filters.search" placeholder="Cautare" class="form-control" />
    <hr>
    <div class="filter-item">
        <label for="runner" class="label-filter">Sportiv</label>
        <select id="runner" v-model="filters.runner" class="custom-select">
            <option value="all">Toți</option>
            <option v-for="runner in filterData.runners" :key="runner.id" :value="runner.id">{{ runner.full_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="club" class="label-filter">Club</label>
        <select id="club" v-model="filters.club" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="competition" class="label-filter">Competiția</label>
        <select id="competition" v-model="filters.competition" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="competition in filterData.competitions" :key="competition.id" :value="competition.id">{{ competition.competition_name}} </option>
        </select>
    </div>
    <div v-if="filterData.groups" class="filter-item">
        <label for="groups" class="label-filter">Grupe</label>
        <select id="group" v-model="filters.group_data" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="group in filterData.groups" :key="group.id" :value="group.id">{{ group.group_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="category" class="label-filter">Categoria Indeplinita</label>
        <select id="category" v-model="filters.category" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="category in filterData.categories" :key="category.id" :value="category.id">{{ category.category_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="wre" class="label-filter">WRE</label>
        <input type="checkbox" name="wre" id="wre" class="custom-select" v-model="filters.wre">
    </div>
    <div class="filter-item">
        <label for="ecn" class="label-filter">ECN</label>
        <input type="checkbox" name="ecn" id="ecn" class="custom-select" v-model="filters.ecn">
    </div>
    <div class="filter-item">
        <label class="label-filter">Îndeplinire</label>
        <label for="confirmed">Confirmat</label>
        <input type="checkbox" id="confirmed" value="confirmed" v-model="filters.status" />
        <label for="pending">În așteptare</label>
        <input type="checkbox" id="pending" value="pending" v-model="filters.status" />
        <label for="unconfirmed">Neconfirmat</label>
        <input type="checkbox" id="unconfirmed" value="unconfirmed" v-model="filters.status" />
    </div>
    <div class="filter-item">
        <label class="label-filter">Data</label>
        <div class="range-wrapper">
            <input type="date" v-model="filters['date[from]']" min="0" class="custom-input" />
            <span class="range-separator">—</span>
            <input type="date" v-model="filters['date[to]']" min="0" class="custom-input" placeholder="Până la" />
        </div>
    </div>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <td @click="orderTable('place')">Locul</td>
                <td @click="orderTable('full_name')">Sportiv</td>
                <td @click="orderTable('club_name')">Club</td>
                <td @click="orderTable('runner_category_name')">Categoria actuala</td>
                <td @click="orderTable('time')">Timpul</td>
                <td @click="orderTable('result_category_name')">Categoria Indeplinita</td>
                <td @click="orderTable('status')">Indeplinire</td>
                <td @click="orderTable('date')">Data</td>
                <td @click="orderTable('competition_name')">Competitia</td>
                <td @click="orderTable('group_name')">Grupa</td>
                <td @click="orderTable('wre_points')">WRE Puncte</td>
                <td @click="orderTable('ecn_points')">ECN Puncte</td>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td>{{element.place}}</td>
                <td><a :href="`runners/${element.runner_id}`">{{element.full_name}}</a></td>
                <td><a :href="`clubs/${element.club_id}`">{{element.club_name}}</a></td>
                <td><a :href="`categories/${element.runner_category_id}`">{{element.runner_category_name}}</a></td>
                <td>{{formatResultTime(element.time)}}</td>
                <td><a :href="`categories/${element.result_category_id}`">{{element.result_category_name}}</a></td>
                <td>{{element.status}}</td>
                <td>{{element.date}}</td>
                <td><a :href="`competitions/${element.competition_id}`">{{element.competition_name}}</a></td>
                <td><a :href="`groups/${element.group_id}`">{{element.group_name}}</a></td>
                <td>{{element.wre_points}}</td>
                <td>{{element.ecn_points}}</td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`results/${element.id}`">
                        Arată
                    </a>
                </td>
                <td>
                    <button class="btn btn-sm btn-success" @click="editElement(element)">
                        Editează
                    </button>
                </td>
                <td>
                    <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                        Șterge
                    </button>
                </td>
            </tr>
        </tbody>
    </table>
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'

const data = ref([])
const filterData = ref({})
const competitionValue = ref("")

const DEFAULT_FILTERS = {
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc",
    "date[from]": "2000-01-01",
    "date[to]": "2100-01-01",
    "search": "",
    "club": "all",
    "runner": "all",
    "competition": "all",
    "category": "all",
    "wre": "false",
    "ecn": "false",
    "group_data": "all",
    "status": []
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
    getFiltersGroupData();
    const cleanParams = {};

    const rangePairs = [
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
        if (value === []) return;
        if (key === 'status' && value.length === 0) return;
        if (key !== 'search' && (value === "" || value === null)) {
            value = DEFAULT_FILTERS[key];
        }

        cleanParams[key] = value;
    });

    try {
        const res = await axios.get('/results.json', { params: cleanParams });
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

    return getData();
    if (urlParams.toString() === '')

        urlParams.forEach((value, key) => {
            if (key in filters) {
                const isNumber = typeof DEFAULT_FILTERS[key] === 'number';
                filters[key] = isNumber ? Number(value) : value;
            }
        });
})

function orderTable(sortKey) {
    const isCurrentSort = filters["sorting[sort_by]"] === sortKey;
    const currentDir = filters["sorting[direction]"];

    filters["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters["sorting[sort_by]"] = sortKey;
}

async function getFiltersData() {
    const cleanParams = {};
    cleanParams["competition"] = filters.competition

    const res = await axios.get('/results/filters.json', { params: cleanParams })

    filterData.value = res.data
}

async function getFiltersGroupData() {
    if (filters.competition === competitionValue.value) return
    competitionValue.value = filters.competition

    if (filters.competition === "all") {
        delete filterData.value.groups
        delete filters.group_data
        return;
    }

    const cleanParams = {};

    cleanParams["competition"] = filters.competition

    const res = await axios.get(`/results/group_filters.json?competition=${filters.competition}`)

    filterData.value.groups = res.data
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}

function formatResultTime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    return (
        String(h).padStart(2, '0') + ':' +
        String(m).padStart(2, '0') + ':' +
        String(s).padStart(2, '0')
    );
}
</script>
