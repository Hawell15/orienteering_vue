<template>
    <h1 style="text-align:center; color:green">Competiții</h1>
    <input type="text" v-model="searchData" placeholder="Cautare" @input="onSearch" class="form-control" />
    <hr>
    <div class="filter-item">
        <label :for="country" class="label-filter">Țara</label>
        <select class="custom-select" @change="filter('country', $event.target.value)">
            <option value="all">Toate</option>
            <option value="international">Internaționale</option>
            <option v-for="country in filter_data.countries" :key="country" :value="country">
                {{ country }}
            </option>
        </select>
    </div>
    <div class="filter-item">
        <label :for="distance_type" class="label-filter">Tipul Distanței</label>
        <select class="custom-select" @change="filter('distance_type', $event.target.value)">
            <option value="all">Toate</option>
            <option v-for="distance_type in filter_data.distance_types" :key="distance_type" :value="distance_type">
                {{ distance_type }}
            </option>
        </select>
    </div>
    <div class="filter-item">
        <label :for="distance_type" class="label-filter">WRE</label>
        <input type="checkbox" name="wre" id="wre" class="custom-select" @change="filter('wre', $event.target.checked)">
    </div>
    <div class="filter-item">
        <label class="label-filter">Data</label>
        <div class="range-wrapper">
            <input type="date" class="custom-input" placeholder="De la" @input="filter('date[from]', $event.target.value)" />
            <span class="range-separator">—</span>
            <input type="date" class="custom-input" placeholder="Până la" @input="filter('date[to]', $event.target.value)" />
        </div>
    </div>
    <button class="btn btn-sm btn-danger" @click="resetFilters">Reseteaza Filtrele</button>
    <hr>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('date')">Data</th>
                <th @click="orderTable('competition_name')">Nume</th>
                <th @click="orderTable('location')">Oraș</th>
                <th @click="orderTable('country')">Țara</th>
                <th @click="orderTable('distance_type')">Tipul Distanței</th>
                <th @click="orderTable('wre_id')">WRE ID</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td><a :href="`competitions/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`competitions/${element.id}`">{{ element.date }}</a></td>
                <td><a :href="`competitions/${element.id}`">{{ element.competition_name }}</a></td>
                <td>{{ element.location }}</td>
                <td>{{ element.country }}</td>
                <td>{{ element.distance_type }}</td>
                <td>{{ element.wre_id }}</td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`competitions/${element.id}`">
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
import { ref, onMounted, computed } from 'vue'

import axios from 'axios'
const data = ref([])
const filter_data = ref([])
const searchData = ref("")

const filters = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc",
    "date[from]": "2000-01-01",
    "date[to]": "2100-01-01"
})

const countries = ref([])
const distanceTypes = ref([])

onMounted(async () => {

    getFiltersData();

    const params = new URLSearchParams(window.location.search);

    for (const key of params.keys()) {
        filters.value[key] = params.get(key);
    }

    getData()
})

async function getFiltersData() {
    const res = await axios.get('/competitions/filters.json')
    filter_data.value = res.data
}

async function getData() {
    const params = new URLSearchParams(filters.value).toString();

    const res = await axios.get(`/competitions.json?${params}`)
    data.value = res.data
    const newUrl = `${window.location.pathname}?${params}`
    window.history.replaceState({}, '', newUrl)
}


function orderTable(sortKey) {
    filters.value["sorting[direction]"] = sortingDirection(sortKey)
    filters.value["sorting[sort_by]"] = sortKey
    getData()
}

function sortingDirection(sortKey) {
    if (filters.value["sorting[sort_by]"] != sortKey || filters.value["sorting[direction]"] == "desc") {
        return "asc"
    } else {
        return "desc"
    }
}

function onSearch() {
    filters.value["search"] = searchData.value
    getData()
}

function filter(key, value) {
    filters.value[key] = value
    getData()
}

function resetFilters() {
    filters.value = []
    getData()
}
</script>
<style scoped>
.label-filter {
    width: 150px;
    display: inline-block;
    text-align: left;
    margin-bottom: 5px;
}

.custom-select,
.custom-input {
    word-wrap: normal;
    width: 140px;
    border-radius: 0.375rem;
    text-align: center;
    background-color: lightblue;
    border: 1px solid #ced4da;
}

.range-wrapper {
    display: inline-flex;
    align-items: center;
    gap: 8px;
}

.range-separator {
    font-weight: 600;
}
</style>
