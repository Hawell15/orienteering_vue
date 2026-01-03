<template>
    <h1 style="text-align:center; color:green">Sportivi</h1>
    <input type="text" v-model="filters.search" placeholder="Cautare" class="form-control" />
    <hr>
    <div class="filter-item">
        <label for="club" class="label-filter">Club</label>
        <select id="club" v-model="filters.club" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="membership" class="label-filter">Afiliere</label>
        <select id="membership" v-model="filters.membership" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="category" class="label-filter">Categoria Actuală</label>
        <select id="category" v-model="filters.category" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="category in filterData.categories" :key="category.id" :value="category.id">{{ category.category_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="best_category" class="label-filter">Titlul Sportiv</label>
        <select id="best_category" v-model="filters.best_category" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="category in filterData.categories" :key="category.id" :value="category.id">{{ category.category_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="gender" class="label-filter">Genul</label>
        <select id="gender" v-model="filters.gender" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="gender in filterData.genders" :key="gender" :value="gender">{{ gender }} </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="wre" class="label-filter">WRE ID</label>
        <input type="checkbox" name="wre" id="wre" class="custom-select" v-model="filters.wre">
    </div>
    <div class="filter-item">
        <label class="label-filter">Anul Nașterii</label>
        <div class="range-wrapper">
            <input type="number" v-model="filters['yob[from]']" min="0" class="custom-input" />
            <span class="range-separator">—</span>
            <input type="number" v-model="filters['yob[to]']" min="0" class="custom-input" placeholder="Până la" />
        </div>
    </div>
    <button class="btn btn-sm btn-danger" @click="resetFilters">Reseteaza Filtrele</button>
    <hr>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <td @click="orderTable('id')">FOS ID</td>
                <td @click="orderTable('full_name')">Nume</td>
                <td @click="orderTable('category_id')">Categoria actuală</td>
                <td @click="orderTable('category_valid')">Valabilitate</td>
                <td @click="orderTable('gender')">Genul</td>
                <td @click="orderTable('yob')">Anul Nașterii</td>
                <td @click="orderTable('club_name')">Club</td>
                <td @click="orderTable('best_category_id')">Titlul Sportiv</td>
                <td @click="orderTable('wre_id')">WRE ID</td>
                <td @click="orderTable('sprint_wre_place')">Sprint WRE</td>
                <td @click="orderTable('forest_wre_place')">Padure WRE</td>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td><a :href="`runners/${element.id}`">{{element.id}}</a></td>
                <td><a :href="`runners/${element.id}`">{{element.full_name}}</a></td>
                <td><a :href="`categories/${element.category_id}`">{{element.category_name}}</a></td>
                <td>{{element.category_valid}}</td>
                <td>{{element.gender}}</td>
                <td>{{element.yob}}</td>
                <td><a :href="`clubs/${element.club_id}`">{{element.club_name}}</a></td>
                <td><a :href="`categories/${element.best_category_id}`">{{element.best_category_name}}</a></td>
                <td>{{element.wre_id}}</td>
                <td>
                    <p v-if="element.sprint_wre_place">{{element.sprint_wre_place}}/{{element.sprint_wre_rang}}</p>
                </td>
                <td>
                    <p v-if="element.forest_wre_place">{{element.forest_wre_place}}/{{element.forest_wre_rang}}</p>
                </td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`runners/${element.id}`">
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
    "yob[from]": "1000",
    "yob[to]": "2100",
    "search": "",
    "club": "all",
    "membership": "all",
    "category": "all",
    "best_category": "all",
    "wre": "false",
    "gender": "all",

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
        { from: "yob[from]", to: "yob[to]" },
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
        const res = await axios.get('/runners.json', { params: cleanParams });
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

    const res = await axios.get('/runners/filters.json', { params: cleanParams })

    filterData.value = res.data
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData();
}
</script>
